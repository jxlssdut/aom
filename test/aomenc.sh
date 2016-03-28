#!/bin/sh
##
##  Copyright (c) 2014 The WebM project authors. All Rights Reserved.
##
##  Use of this source code is governed by a BSD-style license
##  that can be found in the LICENSE file in the root of the source
##  tree. An additional intellectual property rights grant can be found
##  in the file PATENTS.  All contributing project authors may
##  be found in the AUTHORS file in the root of the source tree.
##
##  This file tests aomenc using hantro_collage_w352h288.yuv as input. To add
##  new tests to this file, do the following:
##    1. Write a shell function (this is your test).
##    2. Add the function to aomenc_tests (on a new line).
##
. $(dirname $0)/tools_common.sh

readonly TEST_FRAMES=10

# Environment check: Make sure input is available.
aomenc_verify_environment() {
  if [ ! -e "${YUV_RAW_INPUT}" ]; then
    elog "The file ${YUV_RAW_INPUT##*/} must exist in LIBAOM_TEST_DATA_PATH."
    return 1
  fi
  if [ "$(aomenc_can_encode_vp9)" = "yes" ]; then
    if [ ! -e "${Y4M_NOSQ_PAR_INPUT}" ]; then
      elog "The file ${Y4M_NOSQ_PAR_INPUT##*/} must exist in"
      elog "LIBAOM_TEST_DATA_PATH."
      return 1
    fi
  fi
  if [ -z "$(aom_tool_path aomenc)" ]; then
    elog "aomenc not found. It must exist in LIBAOM_BIN_PATH or its parent."
    return 1
  fi
}

aomenc_can_encode_aom() {
  if [ "$(aom_encode_available)" = "yes" ]; then
    echo yes
  fi
}

aomenc_can_encode_vp9() {
  if [ "$(vp9_encode_available)" = "yes" ]; then
    echo yes
  fi
}

# Echo aomenc command line parameters allowing use of
# hantro_collage_w352h288.yuv as input.
yuv_input_hantro_collage() {
  echo ""${YUV_RAW_INPUT}"
       --width="${YUV_RAW_INPUT_WIDTH}"
       --height="${YUV_RAW_INPUT_HEIGHT}""
}

y4m_input_non_square_par() {
  echo ""${Y4M_NOSQ_PAR_INPUT}""
}

y4m_input_720p() {
  echo ""${Y4M_720P_INPUT}""
}

# Echo default aomenc real time encoding params. $1 is the codec, which defaults
# to aom if unspecified.
aomenc_rt_params() {
  local readonly codec="${1:-aom}"
  echo "--codec=${codec}
    --buf-initial-sz=500
    --buf-optimal-sz=600
    --buf-sz=1000
    --cpu-used=-6
    --end-usage=cbr
    --error-resilient=1
    --kf-max-dist=90000
    --lag-in-frames=0
    --max-intra-rate=300
    --max-q=56
    --min-q=2
    --noise-sensitivity=0
    --overshoot-pct=50
    --passes=1
    --profile=0
    --resize-allowed=0
    --rt
    --static-thresh=0
    --undershoot-pct=50"
}

# Wrapper function for running aomenc with pipe input. Requires that
# LIBAOM_BIN_PATH points to the directory containing aomenc. $1 is used as the
# input file path and shifted away. All remaining parameters are passed through
# to aomenc.
aomenc_pipe() {
  local readonly encoder="$(aom_tool_path aomenc)"
  local readonly input="$1"
  shift
  cat "${input}" | eval "${AOM_TEST_PREFIX}" "${encoder}" - \
    --test-decode=fatal \
    "$@" ${devnull}
}

# Wrapper function for running aomenc. Requires that LIBAOM_BIN_PATH points to
# the directory containing aomenc. $1 one is used as the input file path and
# shifted away. All remaining parameters are passed through to aomenc.
aomenc() {
  local readonly encoder="$(aom_tool_path aomenc)"
  local readonly input="$1"
  shift
  eval "${AOM_TEST_PREFIX}" "${encoder}" "${input}" \
    --test-decode=fatal \
    "$@" ${devnull}
}

aomenc_aom_ivf() {
  if [ "$(aomenc_can_encode_aom)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/aom.ivf"
    aomenc $(yuv_input_hantro_collage) \
      --codec=aom \
      --limit="${TEST_FRAMES}" \
      --ivf \
      --output="${output}"

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_aom_webm() {
  if [ "$(aomenc_can_encode_aom)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/aom.webm"
    aomenc $(yuv_input_hantro_collage) \
      --codec=aom \
      --limit="${TEST_FRAMES}" \
      --output="${output}"

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_aom_webm_rt() {
  if [ "$(aomenc_can_encode_aom)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/aom_rt.webm"
    aomenc $(yuv_input_hantro_collage) \
      $(aomenc_rt_params aom) \
      --output="${output}"
    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_aom_webm_2pass() {
  if [ "$(aomenc_can_encode_aom)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/aom.webm"
    aomenc $(yuv_input_hantro_collage) \
      --codec=aom \
      --limit="${TEST_FRAMES}" \
      --output="${output}" \
      --passes=2

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_aom_webm_lag10_frames20() {
  if [ "$(aomenc_can_encode_aom)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly lag_total_frames=20
    local readonly lag_frames=10
    local readonly output="${AOM_TEST_OUTPUT_DIR}/aom_lag10_frames20.webm"
    aomenc $(yuv_input_hantro_collage) \
      --codec=aom \
      --limit="${lag_total_frames}" \
      --lag-in-frames="${lag_frames}" \
      --output="${output}" \
      --auto-alt-ref=1 \
      --passes=2

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_aom_ivf_piped_input() {
  if [ "$(aomenc_can_encode_aom)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/aom_piped_input.ivf"
    aomenc_pipe $(yuv_input_hantro_collage) \
      --codec=aom \
      --limit="${TEST_FRAMES}" \
      --ivf \
      --output="${output}"

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_vp9_ivf() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9.ivf"
    aomenc $(yuv_input_hantro_collage) \
      --codec=vp9 \
      --limit="${TEST_FRAMES}" \
      --ivf \
      --output="${output}"

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_vp9_webm() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9.webm"
    aomenc $(yuv_input_hantro_collage) \
      --codec=vp9 \
      --limit="${TEST_FRAMES}" \
      --output="${output}"

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_vp9_webm_rt() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9_rt.webm"
    aomenc $(yuv_input_hantro_collage) \
      $(aomenc_rt_params vp9) \
      --output="${output}"

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_vp9_webm_rt_multithread_tiled() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9_rt_multithread_tiled.webm"
    local readonly tilethread_min=2
    local readonly tilethread_max=4
    local readonly num_threads="$(seq ${tilethread_min} ${tilethread_max})"
    local readonly num_tile_cols="$(seq ${tilethread_min} ${tilethread_max})"

    for threads in ${num_threads}; do
      for tile_cols in ${num_tile_cols}; do
        aomenc $(y4m_input_720p) \
          $(aomenc_rt_params vp9) \
          --threads=${threads} \
          --tile-columns=${tile_cols} \
          --output="${output}"
      done
    done

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi

    rm "${output}"
  fi
}

aomenc_vp9_webm_rt_multithread_tiled_frameparallel() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9_rt_mt_t_fp.webm"
    local readonly tilethread_min=2
    local readonly tilethread_max=4
    local readonly num_threads="$(seq ${tilethread_min} ${tilethread_max})"
    local readonly num_tile_cols="$(seq ${tilethread_min} ${tilethread_max})"

    for threads in ${num_threads}; do
      for tile_cols in ${num_tile_cols}; do
        aomenc $(y4m_input_720p) \
          $(aomenc_rt_params vp9) \
          --threads=${threads} \
          --tile-columns=${tile_cols} \
          --frame-parallel=1 \
          --output="${output}"
      done
    done

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi

    rm "${output}"
  fi
}

aomenc_vp9_webm_2pass() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9.webm"
    aomenc $(yuv_input_hantro_collage) \
      --codec=vp9 \
      --limit="${TEST_FRAMES}" \
      --output="${output}" \
      --passes=2

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_vp9_ivf_lossless() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9_lossless.ivf"
    aomenc $(yuv_input_hantro_collage) \
      --codec=vp9 \
      --limit="${TEST_FRAMES}" \
      --ivf \
      --output="${output}" \
      --lossless=1

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_vp9_ivf_minq0_maxq0() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9_lossless_minq0_maxq0.ivf"
    aomenc $(yuv_input_hantro_collage) \
      --codec=vp9 \
      --limit="${TEST_FRAMES}" \
      --ivf \
      --output="${output}" \
      --min-q=0 \
      --max-q=0

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_vp9_webm_lag10_frames20() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly lag_total_frames=20
    local readonly lag_frames=10
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9_lag10_frames20.webm"
    aomenc $(yuv_input_hantro_collage) \
      --codec=vp9 \
      --limit="${lag_total_frames}" \
      --lag-in-frames="${lag_frames}" \
      --output="${output}" \
      --passes=2 \
      --auto-alt-ref=1

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

# TODO(fgalligan): Test that DisplayWidth is different than video width.
aomenc_vp9_webm_non_square_par() {
  if [ "$(aomenc_can_encode_vp9)" = "yes" ] && \
     [ "$(webm_io_available)" = "yes" ]; then
    local readonly output="${AOM_TEST_OUTPUT_DIR}/vp9_non_square_par.webm"
    aomenc $(y4m_input_non_square_par) \
      --codec=vp9 \
      --limit="${TEST_FRAMES}" \
      --output="${output}"

    if [ ! -e "${output}" ]; then
      elog "Output file does not exist."
      return 1
    fi
  fi
}

aomenc_tests="aomenc_aom_ivf
              aomenc_aom_webm
              aomenc_aom_webm_rt
              aomenc_aom_webm_2pass
              aomenc_aom_webm_lag10_frames20
              aomenc_aom_ivf_piped_input
              aomenc_vp9_ivf
              aomenc_vp9_webm
              aomenc_vp9_webm_rt
              aomenc_vp9_webm_rt_multithread_tiled
              aomenc_vp9_webm_rt_multithread_tiled_frameparallel
              aomenc_vp9_webm_2pass
              aomenc_vp9_ivf_lossless
              aomenc_vp9_ivf_minq0_maxq0
              aomenc_vp9_webm_lag10_frames20
              aomenc_vp9_webm_non_square_par"

run_tests aomenc_verify_environment "${aomenc_tests}"
